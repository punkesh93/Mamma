import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/auth_provider.dart';
import '../core/services/openrouter_service.dart';
import '../models/user_model.dart';
import '../core/services/firestore_service.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

class LoggedMeal {
  final String id;
  final String name;
  final DateTime timestamp;
  final int? calories;
  final int? protein;
  final int? iron;
  final int? calcium;

  LoggedMeal({
    required this.id,
    required this.name,
    required this.timestamp,
    this.calories,
    this.protein,
    this.iron,
    this.calcium,
  });

  factory LoggedMeal.fromJson(Map<String, dynamic> json) {
    return LoggedMeal(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      calories: json['calories'],
      protein: json['protein'],
      iron: json['iron'],
      calcium: json['calcium'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'calories': calories,
      'protein': protein,
      'iron': iron,
      'calcium': calcium,
    };
  }
}

class NutritionTab extends StatefulWidget {
  const NutritionTab({super.key});

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  bool _isRequestingPlan = false;
  String? _aiMealPlan;
  final OpenRouterService _aiService = OpenRouterService();
  final FirestoreService _firestoreService = FirestoreService();

  // Meal logging
  final TextEditingController _mealController = TextEditingController();
  bool _isLoggingMeal = false;
  bool _isListening = false;
  String? _loggedMeal;
  List<LoggedMeal> _todayMeals = [];

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;

  // Design Tokens
  final Color _sage = const Color(0xFF2E8B72);
  final Color _sky = const Color(0xFF2A7A90);
  final Color _lavender = const Color(0xFF6B4B9A);
  final Color _ink = const Color(0xFF1A1A3E);
  final Color _rose = const Color(0xFFE8748A);

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadTodayMeals();
  }

  @override
  void dispose() {
    _mealController.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize();
      setState(() {});
    } catch (e) {
      _speechEnabled = false;
    }
  }

  Future<void> _loadTodayMeals() async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;

    try {
      final meals = await _firestoreService.getTodayMeals(user.uid);
      setState(() {
        _todayMeals = (meals as List).map((m) => LoggedMeal.fromJson(m as Map<String, dynamic>)).toList();
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice input not available on this device')),
      );
      return;
    }
    await _speech.listen(
      onResult: (result) => setState(() {
        _mealController.text = result.recognizedWords;
      }),
    );
    setState(() => _isListening = true);
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _logMeal() async {
    if (_mealController.text.trim().isEmpty || _isLoggingMeal) return;

    final user = context.read<AuthProvider>().userData;
    if (user == null) return;

    final isPremium = user.isPremium ?? false;

    setState(() => _isLoggingMeal = true);

    try {
      int? calories, protein, iron, calcium;

      if (isPremium) {
        // Analyze meal with AI for nutrition info
        final nutritionJson = await _aiService.analyzeMealNutrition(
          mealDescription: _mealController.text,
        );

        // Parse the JSON response
        try {
          // OpenRouter might return JSON wrapped in markdown or just raw string
          final cleanJson = nutritionJson.replaceAll('```json', '').replaceAll('```', '').trim();
          final data = jsonDecode(cleanJson);
          calories = data['calories'] as int?;
          protein = data['protein'] as int?;
          iron = data['iron'] as int?;
          calcium = data['calcium'] as int?;
        } catch (e) {
          debugPrint("Failed to parse nutrition JSON: $e");
        }
      }

      final meal = LoggedMeal(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _mealController.text.trim(),
        timestamp: DateTime.now(),
        calories: calories,
        protein: protein,
        iron: iron,
        calcium: calcium,
      );

      await _firestoreService.logMeal(user.uid, meal);

      setState(() {
        _todayMeals.add(meal);
        _loggedMeal = meal.name;
        _mealController.clear();
      });

      // Clear success message after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _loggedMeal = null);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to log meal. Please try again.')),
        );
      }
    } finally {
      setState(() => _isLoggingMeal = false);
    }
  }

  Future<void> _requestAIMealPlan() async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;

    if (!(user.isPremium ?? false)) {
      context.push('/paywall');
      return;
    }

    setState(() {
      _isRequestingPlan = true;
      _aiMealPlan = null;
    });

    try {
      final prompt = '''
      ROLE: You are Mamma Buddy Nutritionist.
      CONTEXT: User is in week ${user.currentWeek} of pregnancy.
      OBJECTIVE: Provide a 1-day meal plan (Breakfast, Lunch, Dinner, 2 Snacks) focused on ${user.currentWeek < 13 ? 'folate and nausea relief' : 'iron and calcium'}.
      LIMITATIONS: Concise, bullet points, celebratory tone.
      ''';

      final response = await _aiService.chat(conversationHistory: [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': 'Please generate my daily meal plan.'},
      ]);

      setState(() => _aiMealPlan = response);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate meal plan. Please check your connection.')),
        );
      }
    } finally {
      setState(() => _isRequestingPlan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userData;
    if (user == null) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Blobs for brand consistency
          Positioned(
            top: -100,
            left: -50,
            child: _buildBgBlob(const Color(0xFF2A7A90).withOpacity(isDark ? 0.08 : 0.05)),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _buildBgBlob(const Color(0xFF2E8B72).withOpacity(isDark ? 0.08 : 0.05)),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Smart Nutrition 🥗',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 28, 
                    color: isDark ? Colors.white : _ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fueling you and your little one',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, 
                    fontStyle: FontStyle.italic, 
                    color: isDark ? Colors.white70 : const Color(0xFF5C5470),
                  ),
                ),
                const SizedBox(height: 32),

                // Today's Meal Logging
                _buildMealLoggingSection(isDark, surfaceColor, onSurfaceColor, user),
                const SizedBox(height: 24),

                // Daily Progress Card
                _buildDailySummaryCard(user, isDark, theme),
                const SizedBox(height: 24),

                // Today's Meals
                if (_todayMeals.isNotEmpty) ...[
                  Text(
                    'Today\'s Meals',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: isDark ? Colors.white : _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTodayMealsList(isDark),
                  const SizedBox(height: 24),
                ],

                // Nutrient Breakdown
                Text(
                  'Key Nutrients',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: isDark ? Colors.white : _ink,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNutrientGrid(user, isDark),
                const SizedBox(height: 24),

                // AI Meal Plan Section
                _buildAIMealPlanSection(isDark, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBgBlob(Color color) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMealLoggingSection(bool isDark, Color surfaceColor, Color onSurfaceColor, UserModel user) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _sky.withOpacity(isDark ? 0.2 : 0.1), 
            _sage.withOpacity(isDark ? 0.2 : 0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _sky.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.pencil_circle, color: isDark ? theme.colorScheme.primary : _sky, size: 20),
              const SizedBox(width: 8),
              Text(
                'Log Your Meal', 
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold, 
                  color: isDark ? Colors.white : _sky,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loggedMeal != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _sage.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: _sage, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Logged: $_loggedMeal',
                      style: GoogleFonts.plusJakartaSans(color: _sage, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _mealController,
              decoration: InputDecoration(
                hintText: 'What did you eat? (e.g., "Eggs and toast")',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, 
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
                filled: true,
                fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: isDark ? BorderSide(color: Colors.white10) : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, 
                color: isDark ? Colors.white : Colors.black,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Voice button
                GestureDetector(
                  onTap: () {
                    if (!(user.isPremium ?? false)) {
                      context.push('/paywall');
                      return;
                    }
                    _isListening ? _stopListening() : _startListening();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening 
                          ? _rose 
                          : (isDark ? Colors.white10 : _sky.withOpacity(0.1)),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: _isListening ? Colors.white : _sky,
                          size: 20,
                        ),
                        if (!(user.isPremium ?? false))
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Icon(Icons.lock, size: 10, color: Colors.amber),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Log button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoggingMeal ? null : _logMeal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sky,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoggingMeal
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text('Log Meal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            if (!(user.isPremium ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  '✨ Premium: AI calculates macros automatically',
                  style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.amber[700], fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayMealsList(bool isDark) {
    return Column(
      children: _todayMeals.map((meal) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isDark ? Border.all(color: Colors.white10) : null,
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _lavender.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(CupertinoIcons.checkmark_seal_fill, color: _lavender, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal.name, 
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600, 
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (meal.calories != null)
                    Text(
                      '${meal.calories} kcal${meal.protein != null ? ' • ${meal.protein}g protein' : ''}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, 
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              _formatTime(meal.timestamp),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10, 
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  Widget _buildDailySummaryCard(UserModel user, bool isDark, ThemeData theme) {
    final water = user.achievedToday?.water ?? 0;
    final maxWater = user.dailyGoals?.water ?? 3000;
    final waterProgress = (water / maxWater).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _sage.withOpacity(isDark ? 0.2 : 0.1), 
            _sky.withOpacity(isDark ? 0.2 : 0.1)
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _sage.withOpacity(isDark ? 0.3 : 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Hydration', 
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700, 
                      color: isDark ? Colors.white : _ink,
                    ),
                  ),
                  Text(
                    '${(water/1000).toStringAsFixed(1)}L / ${(maxWater/1000).toStringAsFixed(1)}L', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _sky),
                  ),
                ],
              ),
              Icon(CupertinoIcons.drop_fill, color: _sky, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: waterProgress,
              minHeight: 12,
              backgroundColor: isDark ? Colors.white10 : Colors.white,
              valueColor: AlwaysStoppedAnimation(_sky),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            waterProgress >= 1.0 ? "Fully Hydrated! 💧" : "Keep sipping, Mama!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, 
              fontWeight: FontWeight.w600, 
              color: _sky,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientGrid(UserModel user, bool isDark) {
    // Calculate totals from logged meals
    int totalCalories = 0, totalProtein = 0, totalIron = 0, totalCalcium = 0;
    for (var meal in _todayMeals) {
      totalCalories += meal.calories ?? 0;
      totalProtein += meal.protein ?? 0;
      totalIron += meal.iron ?? 0;
      totalCalcium += meal.calcium ?? 0;
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildNutrientCard('Calories', '$totalCalories', '${user.dailyGoals?.calories ?? 2200} kcal', _sage, Icons.local_fire_department, isDark),
        _buildNutrientCard('Protein', '${totalProtein}g', '${user.dailyGoals?.protein ?? 75}g', _sky, Icons.egg_alt, isDark),
        _buildNutrientCard('Iron', '${totalIron}mg', '27mg', _sky, Icons.bloodtype, isDark),
        _buildNutrientCard('Calcium', '${totalCalcium}mg', '1000mg', _lavender, Icons.medication, isDark),
      ],
    );
  }

  Widget _buildNutrientCard(String label, String current, String goal, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: Colors.white10) : null,
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label, 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, 
                  fontWeight: FontWeight.w700, 
                  color: isDark ? Colors.white : _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(current, style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: color)),
          Text(
            'Goal: $goal', 
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10, 
              color: isDark ? Colors.white54 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIMealPlanSection(bool isDark, ThemeData theme) {
    final user = context.watch<AuthProvider>().userData;
    final isPremium = user?.isPremium ?? false;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lavender.withOpacity(isDark ? 0.3 : 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _lavender.withOpacity(0.1), 
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.auto_awesome, color: _lavender, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Meal Recommendations', 
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold, 
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Personalized for Week ${user?.currentWeek ?? 0}', 
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11, 
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium) Icon(Icons.lock, size: 16, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 20),
          if (_aiMealPlan != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8F7FF), 
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _aiMealPlan!, 
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, 
                  height: 1.6,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            )
          else if (_isRequestingPlan)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else
            ElevatedButton(
              onPressed: _requestAIMealPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: _lavender,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                isPremium ? 'Generate My Plan' : 'Unlock Premium Meal Plans', 
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
