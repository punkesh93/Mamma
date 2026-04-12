import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../core/services/openrouter_service.dart';

class WellnessTab extends StatefulWidget {
  const WellnessTab({super.key});

  @override
  State<WellnessTab> createState() => _WellnessTabState();
}

class _WellnessTabState extends State<WellnessTab> {
  final OpenRouterService _aiService = OpenRouterService();
  String? _wellnessTip;
  bool _isLoadingTip = false;

  // Design Tokens
  final Color _lavender = const Color(0xFF6B4B9A);
  final Color _rose = const Color(0xFFE8748A);
  final Color _sky = const Color(0xFF2A7A90);
  final Color _sage = const Color(0xFF2E8B72);
  final Color _ink = const Color(0xFF1A1A3E);

  @override
  void initState() {
    super.initState();
    _loadDailyTip();
  }

  Future<void> _loadDailyTip() async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;

    setState(() => _isLoadingTip = true);
    try {
      final prompt = 'You are a warm prenatal wellness coach. Give one short, actionable wellness tip for a mother in week ${user.currentWeek} of pregnancy. Focus on relaxation or gentle movement.';
      final response = await _aiService.chat(conversationHistory: [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': 'Give me today\'s tip.'},
      ]);
      setState(() => _wellnessTip = response);
    } catch (e) {
      setState(() => _wellnessTip = "Take 5 deep breaths and feel your baby's calm today. 💜");
    } finally {
      setState(() => _isLoadingTip = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Wellness & Calm 🧘',
              style: GoogleFonts.dmSerifDisplay(fontSize: 28, color: _ink),
            ),
            const SizedBox(height: 4),
            Text(
              'Nurturing your mind and body',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontStyle: FontStyle.italic, color: const Color(0xFF5C5470)),
            ),
            const SizedBox(height: 24),

            // Daily Wellness Tip
            _buildDailyTipCard(),
            const SizedBox(height: 24),

            // Activity Categories
            Text(
              'Guided Activities',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: _ink),
            ),
            const SizedBox(height: 12),
            _buildActivityGrid(),
            const SizedBox(height: 24),

            // Breathing Exercise Nudge
            _buildBreathingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_lavender.withOpacity(0.1), _rose.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _lavender.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.sparkles, color: _lavender, size: 20),
              const SizedBox(width: 8),
              Text('Daily Affirmation', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _lavender)),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingTip)
            const Center(child: CupertinoActivityIndicator())
          else
            Text(
              _wellnessTip ?? "Loading your peace...",
              style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.5, fontStyle: FontStyle.italic, color: _ink),
            ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildActivityGrid() {
    return Column(
      children: [
        _buildActivityItem('Prenatal Yoga', '15 min • Gentle Stretch', '🧘', _sage, 'Relieve back pain and improve flexibility for birth.'),
        const SizedBox(height: 12),
        _buildActivityItem('Mindful Meditation', '10 min • Calm Mind', '🧠', _sky, 'Sync your heartbeat with your baby\'s and reduce cortisol.'),
        const SizedBox(height: 12),
        _buildActivityItem('Gratitude Journaling', '5 min • Positive Vibes', '📝', _rose, 'Focus on the joy of your journey and bond with baby.'),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String icon, Color color, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: _ink)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey, height: 1.4)),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBreathingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _sky.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1518241353330-0f7941c2d9b5?w=500&q=80'),
          fit: BoxFit.cover,
          opacity: 0.2,
        ),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.wind, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text('Need a moment of calm?', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Try a 2-minute breathing exercise specifically designed for expectant mothers.', 
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.white.withOpacity(0.9), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _sky,
              minimumSize: const Size(160, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Start Breathing', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
