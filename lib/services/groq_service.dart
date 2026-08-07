import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class GroqService {
  GroqService._();

  static final GroqService instance = GroqService._();

  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Best model  use for goal decomposition & reelection analysis (complex reasoning)
  static const modelPro = 'llama-3.3-70b-versatile';

  /// Fast model - use for shorter, simpler completions.
  static const modelFast = 'llama-3.3-8b-instant';

  String? _cachedKey;

  Future<String?> _apiKey() async {
    if (_cachedKey != null) return _cachedKey;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('secrets')
          .doc('keys')
          .get();
      _cachedKey = doc.data()?['groqApi'] as String?;
      return _cachedKey;
    } catch (e) {
      debugPrint('Error getting Groq API key: $e');
      return null;
    }
  }

  /// Sends [prompt] to Groq and returns the raw text response.
  /// Returns null on any failure - never throws.

  Future<String?> complete({
    required String prompt,
    String model = GroqService.modelPro,
    double temperature = 0.2,
    int maxTokens = 2048,
    bool jsonMode = true,
  }) async {
    final key = await _apiKey();
    if (key == null || key.isEmpty) {
      debugPrint('No Groq API key available in firestore secrets/keys/groqApi');
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $key',
        },

        body: jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
          if (jsonMode) 'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['choices'] as List<dynamic>).first['message']['content']
            as String?;
      }
      debugPrint('Groq API returned status code ${response.statusCode}, response: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error completing with Groq: $e');
      return null;
    }
  }
}
