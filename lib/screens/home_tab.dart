import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../providers/auth_provider.dart';
import '../core/services/openrouter_service.dart';
import '../core/services/firestore_service.dart';
import '../models/user_model.dart';

// ── Design tokens matching the app theme ──────────────────────────────────────
const _rose = Color(0xFFE8748A);
const _sky = Color(0xFF2A7A90);
const _sage = Color(0xFF2E8B72);
const _lavender = Color(0xFF6B4B9A);
// ignore: unused_element
const _ink = Color(0xFF1A1A3E);
const _mauve = Color(0xFF5C5470);
const _cream = Color(0xFFFAF5F0);

// ── Baby Milestones ───────────────────────────────────────────────────────────
class BabyMilestone {
  final int week;
  final String size;
  final String weight;
  final String length;
  final String comparison;
  final String comparisonIcon;
  final String development;

  const BabyMilestone({
    required this.week,
    required this.size,
    required this.weight,
    required this.length,
    required this.comparison,
    required this.comparisonIcon,
    required this.development,
  });
}

const _babyMilestones = [
  BabyMilestone(week: 4, size: 'Poppy seed', weight: '1g', length: '0.2cm', comparison: 'Poppy seed', comparisonIcon: '🌱', development: 'The blastocyst has implanted and is starting to develop into an embryo.'),
  BabyMilestone(week: 8, size: 'Raspberry', weight: '1g', length: '1.6cm', comparison: 'Raspberry', comparisonIcon: '🍓', development: "Your baby's heart is beating, and tiny fingers and toes are forming."),
  BabyMilestone(week: 12, size: 'Lime', weight: '14g', length: '5.4cm', comparison: 'Lime', comparisonIcon: '🍋', development: 'Your baby is fully formed and starting to move, though you cannot feel it yet.'),
  BabyMilestone(week: 16, size: 'Avocado', weight: '100g', length: '11.6cm', comparison: 'Avocado', comparisonIcon: '🥑', development: "Your baby's eyes are starting to move, and they can even make a fist."),
  BabyMilestone(week: 20, size: 'Banana', weight: '300g', length: '16.4cm', comparison: 'Banana', comparisonIcon: '🍌', development: "You're halfway there! Your baby is swallowing amniotic fluid and growing hair."),
  BabyMilestone(week: 24, size: 'Corn', weight: '600g', length: '30cm', comparison: 'Ear of Corn', comparisonIcon: '🌽', development: "Your baby's lungs are developing, and they are starting to have a sleep-wake cycle."),
  BabyMilestone(week: 28, size: 'Eggplant', weight: '1kg', length: '37.6cm', comparison: 'Eggplant', comparisonIcon: '🍆', development: 'Your baby can open their eyes and see light through the womb.'),
  BabyMilestone(week: 32, size: 'Squash', weight: '1.7kg', length: '42.4cm', comparison: 'Squash', comparisonIcon: '🎃', development: 'Your baby is practicing breathing and their bones are fully developed but soft.'),
  BabyMilestone(week: 36, size: 'Papaya', weight: '2.6kg', length: '47.4cm', comparison: 'Papaya', comparisonIcon: '🍈', development: 'Your baby is gaining weight rapidly and getting ready for birth.'),
  BabyMilestone(week: 40, size: 'Watermelon', weight: '3.5kg', length: '51.2cm', comparison: 'Watermelon', comparisonIcon: '🍉', development: 'Your baby is full term and ready to meet the world!'),
];

BabyMilestone _getMilestone(int week) {
  return _babyMilestones.reduce((prev, curr) {
    if (week >= curr.week) return curr;
    return prev;
  });
}

// ── Home Tab ─────────────────────────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  bool _weekExpanded = false;
  String? _aiInsight;
  bool _loadingInsight = false;
  bool _wellnessExpanded = false; // ignore: unused_field
  String? _activeWellness;
  bool _showMealPopup = false;
  String _mealInput = '';
  bool _isLoggingMeal = false;
  bool _mealLogged = false;
  int _moodUsage = 0;
  String? _moodFeedback;
  bool _isAnalyzingMood = false;
  bool _nutritionExpanded = false; // ignore: unused_field

  final OpenRouterService _aiService = OpenRouterService();

  @override
  void initState() {
    super.initState();
    _loadAIInsight();
    _checkMoodUsage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersonalizedTips();
    });
  }

  Future<void> _checkMoodUsage() async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = 'mood_usage_${user.uid}_$today';
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _moodUsage = prefs.getInt(key) ?? 0;
    });
  }

  Future<void> _updateMoodUsage() async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final key = 'mood_usage_${user.uid}_$today';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, _moodUsage + 1);
    setState(() {
      _moodUsage++;
    });
  }

  Future<void> _loadAIInsight() async {
    setState(() => _loadingInsight = true);
    try {
      final user = context.read<AuthProvider>().userData;
      if (user != null) {
        final milestone = _getMilestone(user.currentWeek);
        final prompt = '''
        ROLE: You are Mamma Buddy, an expert prenatal coach.
        USER: ${user.name}, Week ${user.currentWeek} of pregnancy.
        CONTEXT: Baby is the size of a ${milestone.size}.
        GOAL: Generate a 1-sentence, highly personalized, medically-sound yet celebratory daily tip or insight.
        STYLE: Empathetic, expert, short (max 20 words).
        ''';
        
        final insight = await _aiService.chat(conversationHistory: [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': 'Generate my insight for today.'},
        ]);
        if (!mounted) return;
        setState(() => _aiInsight = insight);
      }
    } catch (e) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final String mamaName = auth.userData?.name ?? 'Mama';
      if (!mounted) return;
      setState(() => _aiInsight = '$mamaName, you\'re doing an incredible job! Keep listening to your body! 💕');
    } finally {
      if (mounted) {
        setState(() => _loadingInsight = false);
      }
    }
  }

  Future<void> _handleMoodCheck(String mood) async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;

    if (user.plan != 'premium' && _moodUsage >= 3) {
      setState(() => _moodFeedback = "You've used your 3 free daily mood checks. Upgrade to MamaBuddy Plus for unlimited support! 🌸");
      return;
    }

    setState(() {
      _isAnalyzingMood = true;
      _moodFeedback = null;
    });

    try {
      final prompt = 'ROLE: You are Mamma Buddy, an empathetic pregnancy companion. OBJECTIVE: A user feels "$mood" in week ${user.currentWeek} of pregnancy. Provide reassuring feedback. LIMITATIONS: Use simple language. Be celebratory. EXPECTATIONS: 2 concrete, uplifting coping tips.';
      final response = await _aiService.chat(
        conversationHistory: [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': 'I am feeling $mood today.'},
        ],
        isMoodCheck: true,
      );
      setState(() {
        _moodFeedback = response;
      });
      await _updateMoodUsage();
    } catch (e) {
      if (mounted) {
        setState(() => _moodFeedback = "Something went wrong. Please try again! 🌸");
      }
    } finally {
      setState(() => _isAnalyzingMood = false);
    }
  }

  Future<void> _handleQuickMealLog() async {
    if (_mealInput.trim().isEmpty || _isLoggingMeal) return;

    setState(() => _isLoggingMeal = true);
    try {
      final user = context.read<AuthProvider>().userData;
      if (user != null) {
        // Would call AI to analyze meal and update Firestore
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _mealLogged = true;
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _showMealPopup = false;
          _mealInput = '';
          _mealLogged = false;
        });
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoggingMeal = false);
    }
  }

  // ── Wellness Activities ─────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _wellnessActivities = [
    {'key': 'yoga', 'label': 'Prenatal Yoga', 'duration': '15 min', 'icon': '🧘', 'color': const Color(0xFFD8B4E2), 'impact': 'Yoga improves your flexibility and helps your baby settle into the optimal birth position. Each stretch sends calming signals through your body to your little one 💜'},
    {'key': 'breathing', 'label': 'Deep Breathing', 'duration': '5 min', 'icon': '🌬️', 'color': const Color(0xFF7EC8E3), 'impact': 'Deep breathing sends extra oxygen to your baby and lowers stress hormones. Your baby\'s heartbeat actually syncs with yours when you breathe deeply 💕'},
    {'key': 'journal', 'label': 'Gratitude Journal', 'duration': '10 min', 'icon': '📝', 'color': const Color(0xFFF4D03F), 'impact': 'Journaling reduces anxiety and releases feel-good hormones that cross the placenta to your baby. Your positive thoughts create a calm environment for growth 🌟'},
    {'key': 'meditation', 'label': 'Meditation', 'duration': '10 min', 'icon': '🧠', 'color': const Color(0xFFAED6F1), 'impact': 'Meditation lowers cortisol and your baby can sense the calm. Studies show babies of meditating mamas may have better sleep patterns after birth 🌙'},
  ];

  // ── Mood Options ────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _moods = [
    {'label': 'Happy', 'emoji': '🌟', 'color': const Color(0xFFFFF9C4), 'textColor': const Color(0xFFF9A825)},
    {'label': 'Anxious', 'emoji': '🧊', 'color': const Color(0xFFE3F2FD), 'textColor': const Color(0xFF1976D2)},
    {'label': 'Tired', 'emoji': '☁️', 'color': const Color(0xFFE8EAF6), 'textColor': const Color(0xFF3F51B5)},
    {'label': 'Excited', 'emoji': '✨', 'color': const Color(0xFFFCE4EC), 'textColor': const Color(0xFFE91E63)},
    {'label': 'Nauseous', 'emoji': '🤢', 'color': const Color(0xFFE8F5E9), 'textColor': const Color(0xFF4CAF50)},
    {'label': 'Calm', 'emoji': '🌊', 'color': const Color(0xFFE0F7FA), 'textColor': const Color(0xFF00BCD4)},
  ];

  // ── Personalized Tips ───────────────────────────────────────────────────────
  String? _personalizedTips;
  bool _isLoadingTips = false;

  Future<void> _loadPersonalizedTips() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.userData;
    if (user == null || _personalizedTips != null) return;

    if (!(user.isPremium ?? false)) {
      setState(() {
        _personalizedTips = "Tip 1: Listen to your body and rest when you feel tired.\nTip 2: Stay hydrated by drinking at least 8-10 glasses of water daily.\nTip 3: Eat small, frequent meals to help with energy levels.";
        _isLoadingTips = false;
      });
      return;
    }
    
    setState(() => _isLoadingTips = true);
    try {
      final week = user.isPartnerAccount == true && user.partnerId != null ? 
        (await FirestoreService().getUser(user.partnerId!))?.currentWeek ?? user.currentWeek : 
        user.currentWeek;
      
      final tips = await _aiService.getPersonalizedTips(week: week, userName: user.name);
      if (mounted) {
        setState(() => _personalizedTips = tips);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _personalizedTips = "Tip 1: Rest often.\nTip 2: Stay hydrated.\nTip 3: Listen to your body.");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingTips = false);
      }
    }
  }

  Future<void> _syncPartnerId(UserModel user) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final service = FirestoreService();
    final motherAccount = await service.getUserByEmail(user.partnerEmail!);
    if (motherAccount != null) {
      await service.linkPartnerAccount(user.uid, user.partnerEmail!, motherAccount.uid);
      await auth.reloadUser();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userData;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user.isPartnerAccount == true) {
      if (user.partnerEmail != null && user.partnerEmail!.isNotEmpty && user.partnerId == null) {
        _syncPartnerId(user);
      }
      
      if (user.partnerId != null) {
        return StreamBuilder<UserModel?>(
          stream: FirestoreService().streamUser(user.partnerId!),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildDashboard(user, partnerData: snapshot.data!);
          },
        );
      } else {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.search, size: 48, color: _mauve),
                const SizedBox(height: 16),
                Text('Waiting for Mother to join...', style: GoogleFonts.plusJakartaSans(color: _mauve, fontSize: 16)),
                const SizedBox(height: 8),
                Text('We are searching for ${user.partnerEmail}. Make sure she signs up with this email or update it in settings.', style: GoogleFonts.plusJakartaSans(color: _mauve, fontSize: 13), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      }
    }

    return _buildDashboard(user);
  }

  Widget _buildDashboard(UserModel currentUser, {UserModel? partnerData}) {
    final displayUser = partnerData ?? currentUser;
    final week = displayUser.currentWeek.clamp(1, 40);
    final milestone = _getMilestone(week);
    final daysTracked = displayUser.daysTracked ?? 1;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Blobs for brand consistency
          Positioned(
            top: -100,
            right: -50,
            child: _buildBgBlob(const Color(0xFFE8748A).withOpacity(isDark ? 0.08 : 0.05)),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: _buildBgBlob(const Color(0xFF2E8B72).withOpacity(isDark ? 0.08 : 0.05)),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Greeting Header ───────────────────────────────────────
                _buildHeader(currentUser, week, daysTracked, isDark)
                    .animate().fadeIn(duration: 400.ms).slideX(begin: -0.05),
                const SizedBox(height: 24),

                // ── Week Block ───────────────────────────────────────────
                _buildWeekBlock(week, milestone, isDark)
                    .animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // ── Daily Check-in Nudge ──────────────────────────────────────────
                if (_shouldShowCheckIn(displayUser)) 
                  _buildCheckInNudge(displayUser)
                      .animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.9, 0.9)),
                const SizedBox(height: 16),

                // ── AI Insights Card ─────────────────────────────────────
                _buildAIInsightsCard(displayUser, isDark)
                    .animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),

                // ── Personalized Tips Section ────────────────────────────
                _buildPersonalizedTipsSection(displayUser, isDark)
                    .animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 24),

                // ── Nutrition Section ────────────────────────────────────
                _buildNutritionSection(displayUser, isDark)
                    .animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),

                // ── Quick Meal Log Button (Only for Mother) ───────────────────────────────
                if (currentUser.isPartnerAccount != true) ...[
                  _buildQuickMealLogButton()
                      .animate().fadeIn(delay: 550.ms),
                  const SizedBox(height: 16),
                ],

                // ── Wellness Grid ────────────────────────────────────────
                _buildWellnessGrid(isDark)
                    .animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 16),

                // ── Mood Analyzer ─────────────────────────────────────────
                _buildMoodAnalyzer(displayUser, isDark)
                    .animate().fadeIn(delay: 650.ms),
                const SizedBox(height: 16),

                // ── Weekly Progress ──────────────────────────────────────
                _buildWeeklyProgress(displayUser)
                    .animate().fadeIn(delay: 700.ms),
                const SizedBox(height: 16),

                // ── Partner Widget ────────────────────────────────────────
                _buildPartnerWidget(currentUser, isDark)
                    .animate().fadeIn(delay: 750.ms),
                const SizedBox(height: 16),

                // ── Doctor Reports ───────────────────────────────────────
                _buildDoctorReportsButton(isDark)
                    .animate().fadeIn(delay: 800.ms),
                const SizedBox(height: 16),

                // ── Symptom Checker (Only for Mother) ──────────────────────────────
                if (currentUser.isPartnerAccount != true)
                  _buildSymptomChecker(isDark)
                      .animate().fadeIn(delay: 850.ms),
              ],
            ),
          ),

          // ── Meal Popup ─────────────────────────────────────────────────
          if (_showMealPopup) _buildMealPopup(isDark),
          if (_activeWellness != null) _buildWellnessModal(isDark),
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
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
     .moveY(begin: -20, end: 20, duration: 4.seconds, curve: Curves.easeInOut)
     .moveX(begin: -10, end: 10, duration: 3.seconds, curve: Curves.easeInOut);
  }

  Widget _buildHeader(UserModel user, int week, int daysTracked, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user.name.split(' ').first} 🌸',
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 28, 
                color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Week $week • $daysTracked Days Tracked',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, 
                color: isDark ? Colors.white70 : _mauve, 
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                '${user.streakDays}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.orange[300] : Colors.orange.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _shouldShowCheckIn(UserModel user) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return user.lastCheckInDate != today;
  }

  Widget _buildCheckInNudge(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _rose,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _rose.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Check-in',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Log your mood and metrics to keep your streak!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Scroll to mood analyzer or just record checkin
              final today = DateTime.now().toIso8601String().split('T')[0];
              final updatedUser = user.copyWith(lastCheckInDate: today);
              context.read<AuthProvider>().saveUserData(updatedUser);
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Do it now',
              style: GoogleFonts.plusJakartaSans(
                color: _rose,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().shake(delay: 1.seconds);
  }

  Widget _buildPersonalizedTipsSection(UserModel user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Personalized Tips',
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 22,
                  color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Icon(CupertinoIcons.sparkles, color: _rose, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
            border: Border.all(color: _rose.withOpacity(isDark ? 0.2 : 0.1)),
          ),
          child: _isLoadingTips
              ? Center(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: Lottie.network(
                          'https://lottie.host/81180fd9-5ea0-4cd8-aa92-f0450accb671/C60BqKz979.json', // Cute heartbeat loading animation
                          errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(color: _rose),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Crafting your weekly AI tips...', style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white70 : _mauve, fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MarkdownBody(
                      data: _personalizedTips ?? "We couldn't load your tips right now. Please try again later.",
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface, height: 1.5),
                        listBullet: TextStyle(color: _rose),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? Colors.white12 : null),
                    const SizedBox(height: 8),
                    Text(
                      'Content for informational purposes only; consult your healthcare provider for medical concerns.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWeekBlock(int week, BabyMilestone milestone, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rose.withOpacity(isDark ? 0.2 : 0.1)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _rose.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(child: Text(milestone.comparisonIcon, style: const TextStyle(fontSize: 32))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Week $week', style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _rose.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(milestone.comparison, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _rose, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${milestone.weight} • ${milestone.length}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white60 : _mauve)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _weekExpanded = !_weekExpanded),
                icon: Icon(_weekExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, color: isDark ? Colors.white : _mauve),
              ),
            ],
          ),
          if (_weekExpanded) ...[
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white12 : null),
            const SizedBox(height: 12),
            MarkdownBody(
              data: milestone.development, 
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface, height: 1.5),
                strong: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => context.go('/journey'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Learn more about Week $week', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _rose, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 4),
                  const Icon(CupertinoIcons.chevron_right, size: 14, color: _rose),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIInsightsCard(UserModel user, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _lavender.withOpacity(isDark ? 0.2 : 0.1), 
            _rose.withOpacity(isDark ? 0.2 : 0.08)
          ], 
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavender.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [_lavender, _rose]), shape: BoxShape.circle),
                child: Icon(CupertinoIcons.lightbulb_fill, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text('AI Insights', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
              const Spacer(),
              IconButton(
                onPressed: _loadAIInsight,
                icon: Icon(_loadingInsight ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.refresh, color: _rose, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingInsight)
            Row(
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _rose)),
                const SizedBox(width: 8),
                Text('Analyzing your week…', style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? Colors.white70 : _mauve, fontStyle: FontStyle.italic)),
              ],
            )
          else
            MarkdownBody(
              data: _aiInsight ?? 'Loading your personalized insight…',
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.plusJakartaSans(
                  fontSize: 14, 
                  color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface, 
                  fontStyle: FontStyle.italic, 
                  height: 1.5
                ),
                strong: GoogleFonts.plusJakartaSans(
                  fontSize: 14, 
                  color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface, 
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(UserModel user, bool isDark) {
    final protein = user.achievedToday?.protein ?? 0;
    final iron = user.achievedToday?.iron ?? 0;
    final calcium = user.achievedToday?.calcium ?? 0;
    final water = user.achievedToday?.water ?? 0;
    final proteinGoal = user.dailyGoals?.protein ?? 75;
    final ironGoal = 27;
    final calciumGoal = user.dailyGoals?.calcium ?? 1000;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sage.withOpacity(isDark ? 0.2 : 0.1)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.cart_fill, color: _sage, size: 18),
                  const SizedBox(width: 8),
                  Text("Today's Nutrition 🥗", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _sage.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('AI tracked', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _sage, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNutrientBar('Protein', protein, proteinGoal, 'g', _rose, isDark),
          const SizedBox(height: 8),
          _buildNutrientBar('Iron', iron, ironGoal, 'mg', _sky, isDark),
          const SizedBox(height: 8),
          _buildNutrientBar('Calcium', calcium, calciumGoal, 'mg', _lavender, isDark),
          const SizedBox(height: 16),
          Row(
            children: List.generate(8, (i) => Expanded(
              child: Container(
                height: 24,
                margin: EdgeInsets.only(right: i < 7 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < water ? _sky : (isDark ? Colors.white12 : Colors.transparent),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _sky.withOpacity(0.3)),
                ),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Water', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white60 : _mauve)),
              Text('$water/8 💧', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _sky)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientBar(String label, int current, int goal, String unit, Color color, bool isDark) {
    final progress = (current / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: isDark ? Colors.white60 : _mauve)),
            Text('$current$unit / $goal$unit', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withOpacity(isDark ? 0.2 : 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _mauve)),
            Text('$current$unit / $goal$unit', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMealLogButton() {
    return ElevatedButton.icon(
      onPressed: () => setState(() => _showMealPopup = true),
      icon: const Icon(CupertinoIcons.mic_fill, size: 18),
      label: Text('Log Meal — Type or Speak', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _rose,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
    );
  }

  Widget _buildWellnessGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rose.withOpacity(isDark ? 0.2 : 0.1)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.heart_fill, color: _rose, size: 18),
              const SizedBox(width: 8),
              Text('Your Wellness Today 🧘', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: _wellnessActivities.map((act) => _buildWellnessButton(act, isDark)).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/wellness'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: _rose.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Open Wellness Studio', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: _rose)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessButton(Map<String, dynamic> act, bool isDark) {
    final isActive = _activeWellness == act['key'];
    return GestureDetector(
      onTap: () => setState(() => _activeWellness = act['key']),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive 
              ? (act['color'] as Color).withOpacity(0.2) 
              : (isDark ? Colors.white.withOpacity(0.05) : _cream),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive 
                ? (act['color'] as Color).withOpacity(0.4) 
                : _rose.withOpacity(isDark ? 0.2 : 0.1)
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(act['icon'], style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              act['label'], 
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, 
                fontWeight: FontWeight.w600, 
                color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface
              )
            ),
            Text(act['duration'], style: GoogleFonts.plusJakartaSans(fontSize: 10, color: isDark ? Colors.white54 : _mauve)),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodAnalyzer(UserModel user, bool isDark) {
    final isPremium = user.isPremium ?? false;
    final remaining = isPremium ? 'Unlimited ✨' : '${3 - _moodUsage} left';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _lavender.withOpacity(isDark ? 0.2 : 0.1)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.lightbulb_fill, color: _lavender, size: 18),
                  const SizedBox(width: 8),
                  Text("How Are You Feeling? 💭", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                ],
              ),
              Text(remaining, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white70 : _mauve, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            children: _moods.map((mood) => _buildMoodButton(mood)).toList(),
          ),
          if (_moodFeedback != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _lavender.withOpacity(0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: _lavender.withOpacity(0.1))),
              child: Row(
                children: [
                  Expanded(
                    child: _isAnalyzingMood
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_moodFeedback!, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white70 : Theme.of(context).colorScheme.onSurface, height: 1.4)),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _moodFeedback = null),
                    icon: Icon(CupertinoIcons.xmark, size: 16, color: isDark ? Colors.white54 : _mauve),
                  ),
                ],
              ),
            ),
            if (!isPremium && _moodUsage >= 3)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/paywall'),
                  style: ElevatedButton.styleFrom(backgroundColor: _lavender, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: Text('Unlimited with MammaBuddy Plus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoodButton(Map<String, dynamic> mood) {
    return GestureDetector(
      onTap: _isAnalyzingMood ? null : () => _handleMoodCheck(mood['label']),
      child: Container(
        decoration: BoxDecoration(
          color: mood['color'] as Color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: (mood['color'] as Color).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mood['emoji'], style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(mood['label'], style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: mood['textColor'] as Color)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgress(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1A3E), Color(0xFF2E8B72)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.sparkles, color: _rose, size: 18),
              const SizedBox(width: 8),
              Text('Weekly Progress 📊', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressRow('🥗 Meals Logged', '${user.mealsLogged ?? 0} this week'),
          _buildProgressRow('💧 Water Today', '${user.achievedToday?.water ?? 0}/8 glasses'),
          _buildProgressRow('🔥 Calories Today', '${user.achievedToday?.calories ?? 0} kcal'),
          _buildProgressRow('🏆 Total Points', '${user.totalPoints} pts'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/nutrition'),
              style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text('View Full Nutrition', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white70)),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPartnerWidget(UserModel user, bool isDark) {
    final hasPartner = user.partnerId != null;

    return GestureDetector(
      onTap: () {
        if (!(user.isPremium ?? false)) {
          context.push('/paywall');
          return;
        }
        context.go('/partner');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _rose.withOpacity(isDark ? 0.2 : 0.1)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _rose.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(CupertinoIcons.person_2_fill, color: _rose, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasPartner ? 'Partner Connected ✓' : 'Partner Mode', 
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600, 
                      color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface
                    )
                  ),
                  Text(
                    hasPartner ? 'Tap to view shared progress' : 'Invite your partner to share the journey', 
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white54 : _mauve)
                  ),
                ],
              ),
            ),
            if (hasPartner)
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('Accepted', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w600))),
            if (!hasPartner) Icon(user.isPremium == true ? CupertinoIcons.chevron_right : Icons.lock, color: isDark ? Colors.white54 : _mauve, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorReportsButton(bool isDark) {
    return GestureDetector(
      onTap: () => context.go('/doctor'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _rose.withOpacity(isDark ? 0.2 : 0.1)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: _rose.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.description, color: _rose, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor Reports', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                  Text('Upload and analyze with AI', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white54 : _mauve)),
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right, color: isDark ? Colors.white54 : _mauve, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSymptomChecker(bool isDark) {
    final user = context.watch<AuthProvider>().userData;
    final isPremium = user?.isPremium ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sky.withOpacity(isDark ? 0.3 : 0.2)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: _sky, size: 18),
              const SizedBox(width: 8),
              Text('Symptom Checker 🩺', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
              if (!isPremium) const Spacer(),
              if (!isPremium) const Icon(Icons.lock, color: Colors.amber, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Worried about something? Get instant AI analysis.', 
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white60 : _mauve, fontStyle: FontStyle.italic)
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (!isPremium) {
                  context.push('/paywall');
                  return;
                }
                context.go('/journey');
              },
              icon: Icon(isPremium ? CupertinoIcons.sparkles : Icons.lock, size: 16),
              label: Text(
                isPremium ? 'Check Symptoms Now' : 'Unlock Premium Symptom Checker', 
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)
              ),
              style: ElevatedButton.styleFrom(backgroundColor: _sky, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Meal Popup ─────────────────────────────────────────────────────────────
  Widget _buildMealPopup(bool isDark) {
    return GestureDetector(
      onTap: () => setState(() => _showMealPopup = false),
      child: Container(
        color: Colors.black54,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping inside
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.surface, 
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Log Your Meal', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                    IconButton(onPressed: () => setState(() => _showMealPopup = false), icon: Icon(CupertinoIcons.xmark, color: isDark ? Colors.white54 : _mauve)),
                  ],
                ),
                if (_mealLogged)
                  Column(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text('Meal Logged!', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                      Text('Great job fueling you and baby!', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: isDark ? Colors.white60 : _mauve)),
                    ],
                  )
                else
                  Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _mealInput = v),
                        onSubmitted: (_) => _handleQuickMealLog(),
                        style: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'What did you eat? e.g. banana, rice, dal...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: isDark ? Colors.white38 : Colors.grey),
                          filled: true,
                          fillColor: isDark ? Colors.white.withOpacity(0.05) : _cream,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _rose.withOpacity(0.1))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: _rose, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['🍌 Banana', '🍚 Rice & Dal', '🥛 Milk', '🥚 Eggs', '🍎 Apple', '🥗 Salad'].map((s) =>
                          GestureDetector(
                            onTap: () => setState(() => _mealInput = s.substring(2).trim()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.1) : _cream, 
                                borderRadius: BorderRadius.circular(16)
                              ),
                              child: Text(s, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white70 : _mauve)),
                            ),
                          ),
                        ).toList(),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _mealInput.trim().isEmpty || _isLoggingMeal ? null : _handleQuickMealLog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _rose,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoggingMeal
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Log Meal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wellness Modal ────────────────────────────────────────────────────────
  Widget _buildWellnessModal(bool isDark) {
    final activity = _wellnessActivities.firstWhere((a) => a['key'] == _activeWellness);
    return GestureDetector(
      onTap: () => setState(() => _activeWellness = null),
      child: Container(
        color: Colors.black54,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.surface, 
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [activity['color'] as Color, (activity['color'] as Color).withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text(activity['icon'], style: const TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 16),
                Text(activity['label'], style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: isDark ? Colors.white : Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(activity['impact'], style: GoogleFonts.plusJakartaSans(fontSize: 14, color: isDark ? Colors.white70 : _mauve, height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _activeWellness = null),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: isDark ? BorderSide(color: Colors.white24) : null,
                        ),
                        child: Text('Maybe Later', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : null)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => setState(() => _activeWellness = null),
                        style: ElevatedButton.styleFrom(backgroundColor: _rose, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text('✓ Done!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}