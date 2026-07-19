import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:marketplace/services/farm_memory_service.dart';
import 'package:marketplace/services/smart_farmer_agent.dart';
import 'package:marketplace/services/weather_service.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();
  late SmartFarmerAgent _agent;
  bool _agentReady = false;
  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String? _error;
  WeatherData? _weather;
  String _farmerId = '';

  @override
  void initState() {
    super.initState();
    _farmerId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _initAgent();
    _initSpeech();
    _loadWeather();
  }

  void _initAgent() {
    const compileTimeKey = String.fromEnvironment('GENAI_API_KEY');
    final apiKey = compileTimeKey.isNotEmpty
        ? compileTimeKey
        : (dotenv.env['GENAI_API_KEY'] ?? dotenv.env['GOOGLE_API_KEY'] ?? '');
    if (apiKey.isEmpty) {
      setState(() {
        _error =
            'API key not found. Set GENAI_API_KEY at build time or add it to .env.';
        _agentReady = false;
      });
      return;
    }
    _agent = SmartFarmerAgent(apiKey: apiKey);
    setState(() => _agentReady = true);
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize();
    } catch (_) {
      _speechAvailable = false;
    }
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadWeather() async {
    try {
      final weather = await WeatherService.fetchWeather(
        lat: 37.419,
        lon: -122.057,
      );
      if (!mounted) return;
      setState(() => _weather = weather);
    } catch (_) {
      // Weather is optional for the agent; keep empty state if unavailable.
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || !_agentReady) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _error = null;
    });

    _controller.clear();

    try {
      final response = await _agent.sendTextMessage(
        _farmerId,
        text,
        weather: _weather,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _messages.add(
          ChatMessage(text: 'Error: $e', isUser: false, isError: true),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_agentReady) {
      setState(() {
        _error = 'AI agent is not ready yet. Please verify the API key.';
      });
      return;
    }

    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 75,
      );
      if (image == null) return;

      setState(() {
        _messages.add(
          ChatMessage(
            text: 'Uploaded a crop image for diagnosis.',
            isUser: true,
          ),
        );
        _isLoading = true;
        _error = null;
      });

      final response = await _agent.analyzeCropImage(
        _farmerId,
        image,
        weather: _weather,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _messages.add(
          ChatMessage(text: 'Error: $e', isUser: false, isError: true),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleSpeech() async {
    if (!_speechAvailable) return;

    if (_isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isListening = true;
      _error = null;
    });

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final transcript = result.recognizedWords.trim();
          if (transcript.isNotEmpty) {
            _sendMessage(transcript);
          }
          setState(() => _isListening = false);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.confirmation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> _showToolsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Farm Tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.note_add),
                  title: const Text('Create quick note'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _createQuickNote();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedule calendar event'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _createCalendarEvent();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: const Text('Set a farm timer'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _setFarmTimer();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: const Text('View recent diagnoses'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showRecentDiagnoses();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createQuickNote() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create farm note'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Details'),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final title = titleController.text.trim();
      final content = contentController.text.trim();
      if (title.isEmpty || content.isEmpty) return;

      await FarmMemoryService.saveNote(
        _farmerId,
        title: title,
        content: content,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(text: '📝 Note saved: $title', isUser: false),
        );
      });
    }
  }

  Future<void> _createCalendarEvent() async {
    final titleController = TextEditingController();
    final detailsController = TextEditingController();
    DateTime? eventDate;
    Duration duration = const Duration(hours: 1);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Schedule calendar event'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: detailsController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 1),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (selected != null) {
                        setState(() => eventDate = selected);
                      }
                    },
                    child: Text(
                      eventDate == null
                          ? 'Choose date'
                          : 'Date: ${eventDate!.toLocal().toString().split(' ').first}',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && eventDate != null) {
      await FarmMemoryService.scheduleEvent(
        _farmerId,
        title: titleController.text.trim().isEmpty
            ? 'Farm event'
            : titleController.text.trim(),
        description: detailsController.text.trim(),
        startDate: eventDate!,
        duration: duration,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          const ChatMessage(
            text: '📅 Event scheduled successfully.',
            isUser: false,
          ),
        );
      });
    }
  }

  Future<void> _setFarmTimer() async {
    final labelController = TextEditingController();
    final minutesController = TextEditingController(text: '30');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set a farm timer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: minutesController,
                decoration: const InputDecoration(labelText: 'Minutes'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Start'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final minutes = int.tryParse(minutesController.text.trim()) ?? 30;
      await FarmMemoryService.setTimer(
        _farmerId,
        label: labelController.text.trim().isEmpty
            ? 'Field task timer'
            : labelController.text.trim(),
        duration: Duration(minutes: minutes),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: '⏱️ Timer set for $minutes minutes.',
            isUser: false,
          ),
        );
      });
    }
  }

  Future<void> _showRecentDiagnoses() async {
    final diagnoses = await FarmMemoryService.fetchRecentDiagnoses(
      _farmerId,
      limit: 5,
    );
    if (!mounted) return;
    if (diagnoses.isEmpty) {
      setState(() {
        _messages.add(
          const ChatMessage(
            text: 'No recent diagnoses saved yet.',
            isUser: false,
          ),
        );
      });
      return;
    }

    final summary = diagnoses
        .map(
          (record) =>
              '${record.cropType} at ${record.location}: ${record.summary}',
        )
        .join('\n\n');
    setState(() {
      _messages.add(
        ChatMessage(text: '📌 Prior diagnoses:\n$summary', isUser: false),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('HarvestMind'),
          backgroundColor: const Color.fromARGB(255, 53, 177, 94),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Sign in to use the AI Chat and Farm tools.'),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 53, 177, 94),
              Color.fromARGB(255, 76, 175, 80),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'HarvestMind',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.miscellaneous_services,
                        color: Colors.white,
                      ),
                      onPressed: _showToolsSheet,
                    ),
                  ],
                ),
              ),
              if (_weather != null) _buildWeatherSummaryCard(),
              if (_error != null) _buildErrorBanner(),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.agriculture_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ask farming questions, upload crop images, or speak to your smart farm assistant.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[_messages.length - 1 - index];
                          return _buildMessageBubble(msg);
                        },
                      ),
              ),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              hintText: 'Ask your question...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send),
                          onPressed: _isLoading
                              ? null
                              : () => _sendMessage(_controller.text),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              53,
                              177,
                              94,
                            ),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Upload Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _speechAvailable && !_isLoading
                              ? _toggleSpeech
                              : null,
                          icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                          label: Text(
                            _isListening ? 'Listening...' : 'Voice Note',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _speechAvailable
                                ? const Color.fromARGB(255, 53, 177, 94)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error ?? 'An unexpected error occurred.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSummaryCard() {
    final current = _weather?.series.isNotEmpty == true
        ? _weather!.series.first
        : null;
    final text = current != null
        ? 'Current ${current.tempC ?? 'N/A'}°C, humidity ${current.rh2m ?? 'N/A'}%, wind ${current.windSpeed ?? 'N/A'} km/h'
        : 'Weather data is unavailable.';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Weather-aware recommendations enabled. $text',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isError
              ? Colors.red.shade300
              : (msg.isUser
                    ? const Color.fromARGB(255, 53, 177, 94)
                    : Colors.white),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });
}
