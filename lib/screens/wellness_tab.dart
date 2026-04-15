import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../core/services/openrouter_service.dart';

// Ho'oponopono affirmations
const _hooponoponoAffirmations = [
  "I love you. I'm sorry. Please forgive me. Thank you. 💜",
  "I release all negative thoughts and welcome peace into my life.",
  "I am grateful for this miracle of life growing inside me.",
  "I forgive myself and others. I choose love and healing.",
  "Thank you for another day to appreciate the gift of life.",
  "I am at peace with my past, present, and future.",
  "My body is perfect. My baby is healthy and loved.",
  "I release all fear and welcome joy and excitement.",
  "I am surrounded by love and support.",
  "Every breath I take fills me with calm and gratitude.",
];

class WellnessTab extends StatefulWidget {
  const WellnessTab({super.key});

  @override
  State<WellnessTab> createState() => _WellnessTabState();
}

class _WellnessTabState extends State<WellnessTab> with TickerProviderStateMixin {
  final OpenRouterService _aiService = OpenRouterService();
  String? _wellnessTip;
  bool _isLoadingTip = false;

  // Breathing animation
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  bool _isBreathing = false;
  int _breathingSeconds = 0;
  static const int _breathingDuration = 60; // 1 minute breathing session

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

    // Breathing animation setup
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.3).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed && _isBreathing) {
        _breathingController.forward();
      }
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  void _toggleBreathing() {
    setState(() {
      _isBreathing = !_isBreathing;
      if (_isBreathing) {
        _breathingController.forward();
        _startBreathingTimer();
      } else {
        _breathingController.stop();
        _breathingSeconds = 0;
      }
    });
  }

  void _startBreathingTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isBreathing || !mounted) return false;
      setState(() => _breathingSeconds++);
      return _breathingSeconds < _breathingDuration && _isBreathing;
    });
  }

  Future<void> _loadDailyTip() async {
    final user = context.read<AuthProvider>().userData;
    if (user == null) return;

    if (!(user.isPremium ?? false)) {
      setState(() => _wellnessTip = _getHooponoponoAffirmation());
      return;
    }

    setState(() => _isLoadingTip = true);
    try {
      final prompt = 'You are a warm prenatal wellness coach. Give one short, actionable wellness tip for a mother in week ${user.currentWeek} of pregnancy. Focus on relaxation or gentle movement.';
      final response = await _aiService.chat(
        conversationHistory: [
          {'role': 'system', 'content': prompt},
          {'role': 'user', 'content': 'Give me today\'s tip.'},
        ],
        isWellnessTip: true,
      );
      setState(() => _wellnessTip = response);
    } catch (e) {
      // Use Ho'oponopono affirmation as fallback
      setState(() => _wellnessTip = _getHooponoponoAffirmation());
    } finally {
      setState(() => _isLoadingTip = false);
    }
  }

  String _getHooponoponoAffirmation() {
    final index = DateTime.now().day % _hooponoponoAffirmations.length;
    return _hooponoponoAffirmations[index];
  }

  Future<void> _openSpotifyPlaylist() async {
    final spotifyUrl = Uri.parse('https://open.spotify.com/playlist/37i9dQZF1DWTC99MCpbjP8');
    try {
      if (await canLaunchUrl(spotifyUrl)) {
        await launchUrl(spotifyUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Spotify. Please install Spotify app.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Spotify.')),
        );
      }
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

            // Daily Affirmation (Ho'oponopono)
            _buildAffirmationCard(),
            const SizedBox(height: 24),

            // A Moment of Calm - Spotify Playlist
            _buildSpotifyCard(),
            const SizedBox(height: 24),

            // Breathing Exercise
            _buildBreathingCard(),
            const SizedBox(height: 24),

            // Activity Categories
            Text(
              'Guided Activities',
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: _ink),
            ),
            const SizedBox(height: 12),
            _buildActivityGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildAffirmationCard() {
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _lavender.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Ho\'oponopono', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: _lavender)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingTip)
            const Center(child: CupertinoActivityIndicator())
          else
            Text(
              _wellnessTip ?? _getHooponoponoAffirmation(),
              style: GoogleFonts.plusJakartaSans(fontSize: 15, height: 1.5, fontStyle: FontStyle.italic, color: _ink),
            ).animate().fadeIn(),
        ],
      ),
    );
  }

  Widget _buildSpotifyCard() {
    return GestureDetector(
      onTap: _openSpotifyPlaylist,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [const Color(0xFF1DB954).withOpacity(0.1), _sky.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF1DB954).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('A Moment of Calm', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: _ink)),
                      Text('Tap to open calm playlist on Spotify', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note, color: Color(0xFF1DB954), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pregnancy Calm & Relaxation',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_sky.withOpacity(0.1), _sage.withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _sky.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.wind, color: _sky, size: 20),
              const SizedBox(width: 8),
              Text('Start Breathing', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: _sky)),
            ],
          ),
          const SizedBox(height: 20),

          // Breathing animation circle
          AnimatedBuilder(
            animation: _breathingAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _breathingAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _sky.withOpacity(0.6),
                        _sky.withOpacity(0.2),
                        _sky.withOpacity(0.0),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _sky.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _isBreathing ? 'Breathe' : 'Start',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Timer display
          if (_isBreathing) ...[
            Text(
              _formatTime(_breathingSeconds),
              style: GoogleFonts.dmSerifDisplay(fontSize: 32, color: _sky),
            ),
            const SizedBox(height: 4),
            Text(
              'Inhale... Exhale...',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey),
            ),
          ],

          const SizedBox(height: 16),

          // Start/Stop button
          ElevatedButton(
            onPressed: _toggleBreathing,
            style: ElevatedButton.styleFrom(
              backgroundColor: _sky,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              _isBreathing ? 'Stop' : 'Start 1-Minute Session',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: _ink)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: color)),
                const SizedBox(height: 6),
                Text(description, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}