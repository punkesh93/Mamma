import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../core/services/openrouter_service.dart';
import '../models/user_model.dart';

class NutritionTab extends StatefulWidget {
  const NutritionTab({super.key});

  @override
  State<NutritionTab> createState() => _NutritionTabState();
}

class _NutritionTabState extends State<NutritionTab> {
  bool _isRequestingPlan = false;
  String? _aiMealPlan;
  final OpenRouterService _aiService = OpenRouterService();

  // Design Tokens
  final Color _sage = const Color(0xFF2E8B72);
  final Color _sky = const Color(0xFF2A7A90);
  final Color _lavender = const Color(0xFF6B4B9A);
  final Color _ink = const Color(0xFF1A1A3E);

  Future<void> _requestAIMealPlan() async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;

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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Smart Nutrition 🥗',
              style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: _ink),
            ),
            const SizedBox(height: 4),
            Text(
              'Fueling you and your little one',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontStyle: FontStyle.italic, color: const Color(0xFF5C5470)),
            ),
            const SizedBox(height: 24),

            // Daily Progress Card
            _buildDailySummaryCard(user),
            const SizedBox(height: 24),

            // Nutrient Breakdown
            Text(
              'Key Nutrients',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: _ink),
            ),
            const SizedBox(height: 12),
            _buildNutrientGrid(user),
            const SizedBox(height: 24),

            // AI Meal Plan Section
            _buildAIMealPlanSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummaryCard(UserModel user) {
    final water = user.achievedToday?.water ?? 0;
    final maxWater = user.dailyGoals?.water ?? 3000;
    final waterProgress = (water / maxWater).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_sage.withOpacity(0.1), _sky.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _sage.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Hydration', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: _ink)),
                  Text('${(water/1000).toStringAsFixed(1)}L / ${(maxWater/1000).toStringAsFixed(1)}L', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _sky)),
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
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(_sky),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            waterProgress >= 1.0 ? "Fully Hydrated! 💧" : "Keep sipping, Mama!",
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: _sky),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientGrid(UserModel user) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildNutrientCard('Calories', '${user.achievedToday?.calories ?? 0}', '${user.dailyGoals?.calories ?? 2200} kcal', _sage, Icons.local_fire_department),
        _buildNutrientCard('Protein', '${user.achievedToday?.protein ?? 0}g', '${user.dailyGoals?.protein ?? 75}g', _sky, Icons.egg_alt),
        _buildNutrientCard('Iron', '${user.achievedToday?.iron ?? 0}mg', '27mg', _sky, Icons.bloodtype),
        _buildNutrientCard('Calcium', '${user.achievedToday?.calcium ?? 0}mg', '1000mg', _lavender, Icons.medication),
      ],
    );
  }

  Widget _buildNutrientCard(String label, String current, String goal, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
            ],
          ),
          const SizedBox(height: 8),
          Text(current, style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: color)),
          Text('Goal: $goal', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAIMealPlanSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lavender.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _lavender.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.auto_awesome, color: _lavender, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Meal Recommendations', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Personalized for Week ${(context.read<AuthProvider>().userData?.currentWeek ?? 0)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_aiMealPlan != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF8F7FF), borderRadius: BorderRadius.circular(16)),
              child: Text(_aiMealPlan!, style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.6)),
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
              child: Text('Generate My Plan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}
