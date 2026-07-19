import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:marketplace/services/ai_agent_service.dart';
import 'package:marketplace/services/farm_memory_service.dart';
import 'package:marketplace/services/weather_service.dart';

class SmartFarmerAgent {
  final AIAgentService _ai;

  SmartFarmerAgent({
    required String apiKey,
    String model = 'gemini-2.5-flash-lite',
  }) : _ai = AIAgentService(apiKey: apiKey, model: model);

  static const String systemPrompt = '''
You are HarvestMind, a professional agricultural AI assistant.
You support smallholder and commercial farmers with crop disease diagnosis, weather-aware crop management, pest prevention, soil health advice, and realistic farm planning.

When a user provides an image, assume it is a crop sample and prioritize:
- disease diagnosis
- treatment options
- prevention and cultural controls
- weather-based timing for spraying, irrigation, and harvest

When a user asks for reminders, timers, calendar events, or notes, respond with an explicit tool action in JSON format only.
If you decide a tool should be used, include a valid JSON object with keys: action, title, details, due (ISO 8601) or startDate, durationMinutes.

If information is missing, ask follow-up questions.
Keep responses actionable, compassionate, and context-aware.
''';

  Future<String> sendTextMessage(
    String farmerId,
    String userInput, {
    String? cropType,
    String? location,
    WeatherData? weather,
  }) async {
    final memoryContext = await FarmMemoryService.buildMemorySummary(farmerId);
    final weatherContext = _buildWeatherSummary(weather);
    final prompt = _buildPrompt(
      userInput,
      memoryContext,
      weatherContext,
      cropType: cropType,
      location: location,
    );

    final rawResponse = await _ai.generateText(prompt, maxOutputTokens: 600);
    final response = rawResponse.trim();

    await FarmMemoryService.saveConversation(farmerId, 'user', userInput);
    await FarmMemoryService.saveConversation(farmerId, 'assistant', response);

    final toolResult = await _extractAndExecuteTool(farmerId, response);
    if (toolResult != null) {
      return '$response\n\n$toolResult';
    }
    return response;
  }

  Future<String> analyzeCropImage(
    String farmerId,
    XFile image, {
    String? cropType,
    String? location,
    WeatherData? weather,
  }) async {
    final imageUrl = await FarmMemoryService.uploadImage(
      image,
      farmerId: farmerId,
    );
    final memoryContext = await FarmMemoryService.buildMemorySummary(farmerId);
    final weatherContext = _buildWeatherSummary(weather);
    final prompt = _buildPrompt(
      'I am uploading an image for diagnosis: $imageUrl',
      memoryContext,
      weatherContext,
      cropType: cropType,
      location: location,
      imageHint:
          'Please analyze the image URL as a crop sample with leaf, stem, or fruit symptoms.',
    );

    final rawResponse = await _ai.generateText(prompt, maxOutputTokens: 700);
    final response = rawResponse.trim();

    await FarmMemoryService.saveConversation(
      farmerId,
      'user',
      'Uploaded an image for diagnosis.',
    );
    await FarmMemoryService.saveConversation(farmerId, 'assistant', response);
    await FarmMemoryService.saveDiagnosis(
      farmerId,
      cropType: cropType ?? 'Unknown crop',
      location: location ?? 'Unknown location',
      imageUrl: imageUrl,
      summary: response,
    );

    final toolResult = await _extractAndExecuteTool(farmerId, response);
    if (toolResult != null) {
      return '$response\n\n$toolResult';
    }
    return response;
  }

  String _buildWeatherSummary(WeatherData? weather) {
    if (weather == null) {
      return 'Weather information is not available at the moment.';
    }
    final current = weather.series.isNotEmpty ? weather.series.first : null;
    final daily = weather.daily.take(3).toList();
    final buffer = StringBuffer();
    buffer.writeln('Weather summary:');
    if (current != null) {
      buffer.writeln(
        '- Current temperature: ${current.tempC ?? 'N/A'}°C, humidity: ${current.rh2m ?? 'N/A'}%, wind: ${current.windSpeed ?? 'N/A'} km/h ${current.windDir ?? ''}.',
      );
    }
    if (daily.isNotEmpty) {
      for (final day in daily) {
        buffer.writeln(
          '- ${day.date.toLocal().toString().split(' ').first}: high ${day.tempMax ?? 'N/A'}°C, low ${day.tempMin ?? 'N/A'}°C, precipitation ${day.precipitation?.toStringAsFixed(1) ?? 'N/A'} mm.',
        );
      }
    }
    return buffer.toString();
  }

  String _buildPrompt(
    String userInput,
    String memoryContext,
    String weatherContext, {
    String? cropType,
    String? location,
    String? imageHint,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(systemPrompt);
    if (location != null && location.isNotEmpty) {
      buffer.writeln('Farm location: $location.');
    }
    if (cropType != null && cropType.isNotEmpty) {
      buffer.writeln('Crop type: $cropType.');
    }
    buffer.writeln(weatherContext);
    if (memoryContext.isNotEmpty) {
      buffer.writeln('\n${memoryContext.trim()}');
    }
    if (imageHint != null && imageHint.isNotEmpty) {
      buffer.writeln(imageHint);
    }
    buffer.writeln('\nUser asks: $userInput');
    buffer.writeln(
      'Provide a helpful farming response, and include tool JSON only when a reminder or calendar action is needed.',
    );
    return buffer.toString();
  }

  Future<String?> _extractAndExecuteTool(
    String farmerId,
    String response,
  ) async {
    final jsonMatch = RegExp(
      r'\{[\s\S]*"action"[\s\S]*\}',
    ).firstMatch(response);
    if (jsonMatch == null) {
      return null;
    }

    try {
      final toolText = jsonMatch.group(0)!;
      final data = jsonDecode(toolText) as Map<String, dynamic>;
      final action = data['action'] as String?;
      if (action == null) return null;

      switch (action) {
        case 'create_reminder':
          await FarmMemoryService.createReminder(
            farmerId,
            title: data['title'] as String? ?? 'Reminder',
            details: data['details'] as String? ?? '',
            dueDate: DateTime.parse(data['due'] as String),
          );
          return '✅ Reminder created successfully.';
        case 'set_timer':
          final minutes = (data['durationMinutes'] as num?)?.toInt() ?? 0;
          await FarmMemoryService.setTimer(
            farmerId,
            label: data['title'] as String? ?? 'Timer',
            duration: Duration(minutes: minutes),
          );
          return '⏱️ Timer set for $minutes minutes.';
        case 'schedule_event':
          await FarmMemoryService.scheduleEvent(
            farmerId,
            title: data['title'] as String? ?? 'Farm event',
            description: data['description'] as String? ?? '',
            startDate: DateTime.parse(data['startDate'] as String),
            duration: Duration(
              minutes: (data['durationMinutes'] as num?)?.toInt() ?? 60,
            ),
          );
          return '📅 Event scheduled successfully.';
        case 'save_note':
          await FarmMemoryService.saveNote(
            farmerId,
            title: data['title'] as String? ?? 'Farm note',
            content: data['details'] as String? ?? '',
          );
          return '📝 Note saved to your farm memory.';
        case 'retrieve_diagnoses':
          final diagnoses = await FarmMemoryService.fetchRecentDiagnoses(
            farmerId,
            limit: 3,
          );
          if (diagnoses.isEmpty) {
            return 'No prior diagnoses were found in your farm memory.';
          }
          final summary = diagnoses
              .map(
                (record) =>
                    '- ${record.cropType} at ${record.location}: ${record.summary}',
              )
              .join('\n');
          return '📌 Recent diagnoses:\n$summary';
        default:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}
