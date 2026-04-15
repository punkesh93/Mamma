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
    final response = _fallbackResponses[type] ?? _fallbackResponses['wellness']!;
    if (response is List) {
      final responses = (_fallbackResponses[type] ?? _fallbackResponses['wellness']!) as List<String>;
      return responses[DateTime.now().millisecond % responses.length];
    }
    return response as String;
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
    const systemPrompt = '''
    ROLE: You are "MammaBuddy Senior Maternal Consultant", an expert in prenatal care and physiology.
    
    OBJECTIVE: Provide a professional, expert-level analysis of the provided maternal health metrics. 
    
    INSTRUCTIONS:
    1. EXAMINE: Gestational Age, BP, Hemoglobin, FHR, and Urine Screenings.
    2. WEIGHT EVALUATION: Compare total weight gain against Pre-pregnancy BMI using clinical ranges:
       - BMI < 18.5 (Underweight): 12.5–18.0 kg
       - BMI 18.5–24.9 (Normal): 11.5–16.0 kg
       - BMI 25.0–29.9 (Overweight): 7.0–11.5 kg
       - BMI ≥ 30 (Obese): 5.0–9.0 kg
    3. STATUS: For each vital, use clear status indicators: [OPTIMAL ✅], [MONITOR ⚠️], or [ACTION REQUIRED 🚨].
    4. TONE: Professional, expert, yet deeply supportive. 
    5. FORMATTING: Use clean Markdown (Headers, Bold text, Bullet points).
    
    CRITICAL SAFETY RULES:
    - If BP >= 140/90 or Urine Protein is PRESENT, state CONCERNING (Preeclampsia risk) and advise immediate medical contact.
    - If Hemoglobin < 11.0 g/dL, state MONITOR (Anemia risk) and suggest iron-rich foods/doctor consultation.
    - ALWAYS include a bold disclaimer: "**Disclaimer: This AI analysis is for educational purposes and is NOT medical advice. Always consult your obstetrician for clinical decisions.**"
    
    CLOSING: Provide one empowering "Consultant's Note" for the mother's mental wellbeing.
    ''';

    return _callOpenRouter(
      systemPrompt: systemPrompt,
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
Use the user's name and week for personalization. Maintain a warm, supportive tone.
Do not include any pleasantries or conversational filler outside the tips. Just return the 3 tips as a list.''';

    return _callOpenRouter(
      systemPrompt: prompt,
      userMessage: 'Please give me my weekly tips.',
      fallbackType: 'wellness',
    );
  }

  // ── AI Meal Nutrition Analysis (NEW) ───────────────────────────────────────
  Future<String> analyzeMealNutrition({required String mealDescription}) async {
    const prompt = '''You are a precise nutrition analyzer.
Analyze the meal described by the user.
Extract the following: calories (kcal), protein (g), iron (mg), and calcium (mg).
Return ONLY a JSON object in this format:
{"calories": X, "protein": X, "iron": X, "calcium": X}
If any value is unknown, use 0. Do not include any text before or after the JSON.''';

    return _callOpenRouter(
      systemPrompt: prompt,
      userMessage: mealDescription,
      fallbackType: 'meal_plan',
    );
  }

  // ── For the AI Chat screen ─────────────────────────────────
  Future<String> chat({
    required List<Map<String, String>> conversationHistory,
    bool isMoodCheck = false,
    bool isWellnessTip = false,
  }) async {
    return _callOpenRouter(
      systemPrompt: 'You are Mamma Buddy, an empathetic, highly knowledgeable, and comforting AI maternity assistant. Provide concise, evidence-based advice regarding pregnancy, nutrition, and wellness. Always maintain a warm, supportive tone. Do not diagnose medical conditions; advise consulting a doctor for emergencies.',
      userMessages: conversationHistory,
      fallbackType: isMoodCheck ? 'mood' : (isWellnessTip ? 'wellness' : 'insight'),
    );
  }

  // ── Shared internal method ─────────────────────────────────
  Future<String> _callOpenRouter({
    required String systemPrompt,
    String? userMessage,
    List<Map<String, String>>? userMessages,
    String fallbackType = 'wellness',
  }) async {
    // Check if API key is valid
    if (_apiKey.isEmpty || _apiKey.contains('REPLACE')) {
      return _getFallbackResponse(fallbackType);
    }

    final List<Map<String, dynamic>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    if (userMessages != null) {
      messages.addAll(userMessages);
    } else if (userMessage != null) {
      messages.add({'role': 'user', 'content': userMessage});
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
          'messages': messages,
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] as String;
        }
      }
      return _getFallbackResponse(fallbackType);
    } catch (e) {
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
      ).timeout(const Duration(seconds: 30));

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
