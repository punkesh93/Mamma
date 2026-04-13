import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class OpenRouterService {
  String get _apiKey => ApiConstants.openRouterApiKey;

  // Fallback response when API fails
  static const _fallbackResponses = {
    'mood': [
      "You're doing amazing! Remember to stay hydrated and rest when you can. 💕",
      "Your body is doing incredible work. Be gentle with yourself today. 🌸",
      "Every symptom is a sign of the miracle growing inside you. You're strong! 💪",
      "Take a moment to appreciate how far you've come. You're doing great! 🌟",
    ],
    'insight': [
      "You're doing an incredible job! Keep listening to your body. 💕",
      "Remember to stay hydrated and get plenty of rest. Your baby feels your love! 🌸",
      "Each day is a step closer to meeting your little one. You're amazing! 💪",
    ],
    'wellness': [
      "Take 5 deep breaths and feel your baby's calm today. 💜",
      "Gentle movement can help ease discomfort. Try a short walk today. 🚶",
      "Rest is productive too. Your body is doing amazing work! 🌟",
    ],
    'meal_plan': """
• Breakfast: Start with protein-rich eggs and whole grain toast
• Snack: A handful of almonds for healthy fats
• Lunch: Lean chicken with leafy greens and quinoa
• Snack: Greek yogurt with berries
• Dinner: Salmon with roasted vegetables
• Stay hydrated with 8+ glasses of water!
""",
    'symptoms': """
Thank you for sharing. Many pregnancy symptoms are normal, but it's always best to consult your healthcare provider for personalized advice.

In general:
• Mild discomfort is often normal
• Stay hydrated and rest
• Contact your doctor for any concerning symptoms

Remember, you're doing great! 🌸
""",
    'tracker': """
Your health metrics show you're on track!

Continue:
• Staying active with gentle exercises
• Eating nutrient-rich foods
• Attending regular prenatal checkups

You're doing amazing work! 💕
""",
  };

  String _getFallbackResponse(String type) {
    final responses = _fallbackResponses[type] ?? _fallbackResponses['wellness']!;
    return responses[DateTime.now().millisecond % responses.length];
  }

  // ── For the upgraded Symptom Checker ──────────────────────
  Future<String> analyzeSymptoms({required String symptomsPayload}) async {
    return _callOpenRouter(
      systemPrompt: '''You are an empathetic maternal health AI assistant.
Analyze the described symptoms in the context of pregnancy.
Provide supportive, evidence-based guidance. Flag anything urgent.
Always advise consulting a doctor for serious or persistent symptoms.
Never diagnose. Always be warm, clear, and reassuring.''',
      userMessage: symptomsPayload,
      fallbackType: 'symptoms',
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
      fallbackType: 'tracker',
    );
  }

  // ── Personalized Tips (NEW) ────────────────────────────────────────────────
  Future<String> getPersonalizedTips({required int week, required String userName}) async {
    String focusAreas = '';
    if (week <= 8) {
      focusAreas = 'nausea/morning sickness, fatigue, and ginger/crackers tips';
    } else if (week <= 20) {
      focusAreas = 'heartburn, constipation, and round ligament pain';
    } else {
      focusAreas = 'backaches, swelling, and calcium-rich foods';
    }

    final prompt = '''You are MammaBuddy, a professional but empathetic AI maternal health assistant.
User Name: $userName
Current Pregnancy Week: $week

Your task is to provide exactly 3 short, highly actionable tips focusing specifically on: $focusAreas.
Use the user's name and week for personalization. Maintain a warm, "antigravity" tone.
Do not include any pleasantries or conversational filler outside the tips. Just return the 3 tips.''';

    if (_apiKey.isEmpty || _apiKey.contains('REPLACE')) {
      return _getFallbackResponse('wellness');
    }

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
          'model': 'openrouter/free',
          'messages': [
            {'role': 'system', 'content': prompt},
            {'role': 'user', 'content': 'Please give me my weekly tips.'},
          ],
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      return _getFallbackResponse('wellness');
    } catch (e) {
      return _getFallbackResponse('wellness');
    }
  }

  // ── For the AI Chat screen ─────────────────────────────────
  Future<String> chat({
    required List<Map<String, String>> conversationHistory,
    bool isMoodCheck = false,
    bool isWellnessTip = false,
  }) async {
    // Check if API key is valid
    if (_apiKey.isEmpty || _apiKey.contains('REPLACE')) {
      return isMoodCheck
          ? _getFallbackResponse('mood')
          : isWellnessTip
              ? _getFallbackResponse('wellness')
              : _getFallbackResponse('insight');
    }

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
      // Fallback on API error
      return isMoodCheck
          ? _getFallbackResponse('mood')
          : isWellnessTip
              ? _getFallbackResponse('wellness')
              : _getFallbackResponse('insight');
    } catch (e) {
      // Return fallback on network error
      return isMoodCheck
          ? _getFallbackResponse('mood')
          : isWellnessTip
              ? _getFallbackResponse('wellness')
              : _getFallbackResponse('insight');
    }
  }

  // ── Shared internal method ─────────────────────────────────
  Future<String> _callOpenRouter({
    required String systemPrompt,
    required String userMessage,
    String fallbackType = 'wellness',
  }) async {
    // Check if API key is valid
    if (_apiKey.isEmpty || _apiKey.contains('REPLACE')) {
      return _getFallbackResponse(fallbackType);
    }

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
      // Fallback on API error
      return _getFallbackResponse(fallbackType);
    } catch (e) {
      // Return fallback on network error
      return _getFallbackResponse(fallbackType);
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
