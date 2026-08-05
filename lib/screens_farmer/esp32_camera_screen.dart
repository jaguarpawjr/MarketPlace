import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace/services/ml_service.dart';
import 'package:marketplace/models/disease_info.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:mjpeg_view/mjpeg_view.dart';

class Esp32CameraScreen extends StatefulWidget {
  const Esp32CameraScreen({super.key});

  @override
  State<Esp32CameraScreen> createState() => _Esp32CameraScreenState();
}

class _Esp32CameraScreenState extends State<Esp32CameraScreen> {
  final TextEditingController _ipController = TextEditingController();
  String _streamUrl = '';
  String _captureUrl = '';
  bool _isConnected = false;
  bool _isCapturing = false;
  ImageProvider? _capturedImage;
  final MlService _mlService = MlService();
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
    _mlService.initialize();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('esp32_ip') ?? '192.168.1.100';
    _ipController.text = savedIp;
    _updateUrls(savedIp);
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32_ip', ip);
  }

  void _updateUrls(String ip) {
    setState(() {
      _streamUrl = 'http://$ip:81/stream';
      _captureUrl = 'http://$ip/capture';
      _isConnected = false;
      _capturedImage = null;
    });
  }

  void _connectToCamera() {
    final ip = _ipController.text.trim();
    if (ip.isNotEmpty) {
      _saveIp(ip);
      _updateUrls(ip);
      setState(() {
        _isConnected = true;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_captureUrl.isEmpty) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final response = await http
          .get(Uri.parse(_captureUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        setState(() {
          _capturedImage = MemoryImage(response.bodyBytes);
          _isConnected = false; // Stop stream to show capture
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image captured from truck!')),
          );
        }
      } else {
        _showError('Failed to capture image: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error connecting to camera: $e');
    } finally {
      setState(() {
        _isCapturing = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _capturedImage = MemoryImage(bytes);
          _isConnected = false; // Stop stream to show capture
        });
      }
    } catch (e) {
      _showError('Failed to select image: $e');
    }
  }

  Future<void> _analyzeDisease() async {
    if (_capturedImage == null) {
      _showError('Please capture an image first.');
      return;
    }

    if (_capturedImage is! MemoryImage) {
      _showError('Unsupported image format.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final Uint8List bytes = (_capturedImage as MemoryImage).bytes;
      final result = await _mlService.runInference(bytes);

      if (mounted) {
        if (result != null) {
          final disease = result['disease'];
          final confidence = (result['confidence'] as double) * 100;

          final info = diseaseData[disease];

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.analytics, color: Colors.greenAccent, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'Analysis Result',
                            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Disease Name & Confidence
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detected:',
                                style: TextStyle(color: Colors.white54, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                info?.title ?? disease,
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Confidence',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${confidence.toStringAsFixed(1)}%',
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Comprehensive Info
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (info != null) ...[
                            _buildInfoSection(Icons.info_outline, 'What is it?', info.description),
                            _buildInfoSection(Icons.search, 'Symptoms', info.symptoms),
                            _buildInfoSection(Icons.medical_services_outlined, 'Treatment', info.treatment),
                            _buildInfoSection(Icons.shield_outlined, 'Prevention', info.prevention),
                          ] else ...[
                            const Text(
                              'No detailed information available for this detection.',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          _showError('Analysis failed. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) _showError('Error analyzing image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark mode background
      appBar: AppBar(
        title: const Text('Crop Scanning'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // IP Address Input Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi, color: Colors.greenAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ipController,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 18, 17, 17),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter Camera IP',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _connectToCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withOpacity(0.2),
                      foregroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Connect'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Phone Camera Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(
                    Icons.photo_camera,
                    color: Colors.white70,
                    size: 20,
                  ),
                  label: const Text(
                    'Use Phone Camera',
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: TextButton.styleFrom(backgroundColor: Colors.white10),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(
                    Icons.photo_library,
                    color: Colors.white70,
                    size: 20,
                  ),
                  label: const Text(
                    'Gallery',
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: TextButton.styleFrom(backgroundColor: Colors.white10),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Camera Feed or Captured Image
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.greenAccent.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_capturedImage != null)
                    Image(
                      image: _capturedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  else if (_isConnected)
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: MjpegView(
                          uri: _streamUrl,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Text(
                        'Enter IP and tap Connect to view stream',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),

                  // Scanning Bracket Overlay
                  if (_isConnected && _capturedImage == null)
                    Positioned.fill(
                      child: CustomPaint(painter: BracketPainter()),
                    ),

                  if (_isCapturing || _isAnalyzing)
                    const CircularProgressIndicator(color: Colors.greenAccent),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: _buildGlassButton(
                    onPressed: _isConnected ? _captureImage : null,
                    icon: Icons.camera_alt,
                    label: 'Capture',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildGlassButton(
                    onPressed: _capturedImage != null ? _analyzeDisease : null,
                    icon: Icons.analytics,
                    label: 'Analyze Disease',
                    color: Colors.greenAccent,
                    isPrimary: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_capturedImage != null)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _capturedImage = null;
                    if (_ipController.text.isNotEmpty) {
                      _isConnected = true; // resume stream
                    }
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.white54),
                label: const Text(
                  'Retake Picture',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
    bool isPrimary = false,
  }) {
    final bgColor = isPrimary
        ? Colors.greenAccent.withOpacity(0.2)
        : Colors.white.withOpacity(0.1);

    final borderColor = isPrimary
        ? Colors.greenAccent.withOpacity(0.5)
        : Colors.white.withOpacity(0.2);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: onPressed == null ? Colors.white.withOpacity(0.05) : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: onPressed == null ? Colors.transparent : borderColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: onPressed == null ? Colors.white24 : color,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: onPressed == null ? Colors.white24 : color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for the scanning bracket overlay
class BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final double length = 40;
    final double padding = 30;

    // Top Left
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding + length, padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, padding + length),
      paint,
    );

    // Top Right
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(size.width - padding - length, padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(size.width - padding, padding + length),
      paint,
    );

    // Bottom Left
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding + length, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(padding, size.height - padding - length),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding),
      Offset(size.width - padding - length, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, size.height - padding),
      Offset(size.width - padding, size.height - padding - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
