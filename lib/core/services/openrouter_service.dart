import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class OpenRouterService {
  String get _apiKey => ApiConstants.openRouterApiKey;

  // ── For the upgraded Symptom Checker ──────────────────────
  Future<String> analyzeSymptoms({required String symptomsPayload}) async {
    return _callOpenRouter(
      systemPrompt: '''You are an empathetic maternal health AI assistant.
Analyze the described symptoms in the context of pregnancy.
Provide supportive, evidence-based guidance. Flag anything urgent.
Always advise consulting a doctor for serious or persistent symptoms.
Never diagnose. Always be warm, clear, and reassuring.''',
      userMessage: symptomsPayload,
    );
  }

  // ── For the new Maternal Health Tracker ───────────────────
  Future<String> analyzeMaternalMetrics({required String metricsPayload}) async {
    return _callOpenRouter(
      systemPrompt: '''You are MammaAI, an expert maternal health assistant.
Analyze the pregnancy metrics provided. For each metric:
1. State if it is NORMAL ✅, BORDERLINE ⚠️, or CONCERNING 🚨
2. Give a brief, kind explanation
3. Flag anything requiring immediate medical attention
4. End with an overall wellness summary and one positive affirmation

Clinical thresholds:
- Gestational Age: Normal ≤42 weeks
- BP: Warn if ≥140/90 (preeclampsia risk)
- Hemoglobin: Warn if <11 g/dL (anemia)
- FHR: Normal 110–160 bpm
- Urine Protein/Sugar/Bacteria: Any presence = flag
- Weight gain per BMI category as provided

You are NOT a replacement for professional care. Always say so.''',
      userMessage: metricsPayload,
    );
  }

  // ── For the AI Chat screen ─────────────────────────────────
  Future<String> chat({
    required List<Map<String, String>> conversationHistory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.openRouterBaseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': ApiConstants.appReferer,
          'X-Title': ApiConstants.appTitle,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': ApiConstants.openRouterModel,
          'messages': [
            {
              'role': 'system',
              'content': 'You are Mamma Buddy, an empathetic, highly knowledgeable, and comforting AI maternity assistant. Provide concise, evidence-based advice regarding pregnancy, nutrition, and wellness. Always maintain a warm, supportive tone. Do not diagnose medical conditions; advise consulting a doctor for emergencies.',
            },
            ...conversationHistory,
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      throw Exception('API error: ${response.statusCode}');
    } catch (e) {
      throw Exception('Chat failed: $e');
    }
  }

  // ── Shared internal method ─────────────────────────────────
  Future<String> _callOpenRouter({
    required String systemPrompt,
    required String userMessage,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.openRouterBaseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': ApiConstants.appReferer,
          'X-Title': ApiConstants.appTitle,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': ApiConstants.openRouterModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      throw Exception('OpenRouter error: ${response.statusCode}');
    } catch (e) {
      throw Exception('AI analysis failed: $e');
    }
  }

  // ── AI Medical Document Analysis ─────────────────────────────────────────

  Future<String> analyzeMedicalReport({required String prompt, required String base64Image}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.openRouterBaseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': ApiConstants.appReferer, 
        },
        body: jsonEncode({
          // Using a model that supports vision
          "model": "openai/gpt-4o-mini",
          "messages": [
            {
              "role": "user",
              "content": [
                {
                  "type": "text",
                  "text": prompt
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:image/jpeg;base64,$base64Image"
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception("Failed to analyze medical report: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error during API request: $e");
    }
  }
}
