import 'dart:convert';

import 'package:http/http.dart' as http;

/// A lightweight service for calling Google's Generative AI (Gemini API).
///
/// Usage:
/// final svc = AIAgentService(apiKey: 'YOUR_KEY');
/// final text = await svc.generateText('Hello world');
class AIAgentService {
  final String apiKey;

  /// Model to use. Defaults to gemini-2.5-pro for latest capabilities.
  final String model;

  /// Base URL for the Gemini API.
  final String baseUrl;
//! todo:
  AIAgentService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash-lite',
    this.baseUrl = 'https://generativelanguage.googleapis.com',
  });

  /// Generate text for a prompt. Returns the generated string on success.
  /// Supports open-ended questions and general knowledge queries.
  Future<String> generateText(
    String prompt, {
    int maxOutputTokens = 512,
  }) async {
    final url = Uri.parse(
      '$baseUrl/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final Map<String, dynamic> payload = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'maxOutputTokens': maxOutputTokens,
        'temperature': 0.7,
      },
    };

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (resp.statusCode != 200) {
      throw AIAgentException(
        'Request failed with status ${resp.statusCode}: ${resp.body}',
      );
    }

    final Map<String, dynamic> decoded = jsonDecode(resp.body);

    // Extract text from Gemini response format.
    if (decoded.containsKey('candidates') && decoded['candidates'] is List) {
      final candidates = decoded['candidates'] as List<dynamic>;
      if (candidates.isNotEmpty) {
        final first = candidates[0] as Map<String, dynamic>;
        if (first.containsKey('content') && first['content'] is Map) {
          final content = first['content'] as Map<String, dynamic>;
          if (content.containsKey('parts') && content['parts'] is List) {
            final parts = content['parts'] as List<dynamic>;
            if (parts.isNotEmpty && parts[0] is Map) {
              final part = parts[0] as Map<String, dynamic>;
              if (part.containsKey('text')) {
                return part['text'] as String;
              }
            }
          }
        }
      }
    }

    // Fallback: return the raw body
    return resp.body;
  }
}

class AIAgentException implements Exception {
  final String message;
  AIAgentException(this.message);
  @override
  String toString() => 'AIAgentException: $message';
}
